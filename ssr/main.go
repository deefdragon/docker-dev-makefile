package main

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"mime/multipart"
	"net/http"
	"net/url"
	"os"
	"strings"

	"cgt.name/pkg/go-mwclient"
)

type Mediawiki struct {
	XMLName        xml.Name `xml:"mediawiki"`
	Text           string   `xml:",chardata"`
	Xmlns          string   `xml:"xmlns,attr"`
	Xsi            string   `xml:"xsi,attr"`
	SchemaLocation string   `xml:"schemaLocation,attr"`
	Version        string   `xml:"version,attr"`
	Lang           string   `xml:"lang,attr"`
	Siteinfo       struct {
		Text       string `xml:",chardata"`
		Sitename   string `xml:"sitename"`
		Base       string `xml:"base"`
		Generator  string `xml:"generator"`
		Case       string `xml:"case"`
		Namespaces struct {
			Text      string `xml:",chardata"`
			Namespace []struct {
				Text string `xml:",chardata"`
				Key  string `xml:"key,attr"`
			} `xml:"namespace"`
		} `xml:"namespaces"`
	} `xml:"siteinfo"`
	Page []struct {
		Text         string `xml:",chardata"`
		Title        string `xml:"title"`
		ID           string `xml:"id"`
		Restrictions string `xml:"restrictions"`
		Revision     []struct {
			Chardata    string `xml:",chardata"`
			ID          string `xml:"id"`
			Timestamp   string `xml:"timestamp"`
			Contributor struct {
				Text     string `xml:",chardata"`
				Username string `xml:"username"`
				ID       string `xml:"id"`
				IP       string `xml:"ip"`
			} `xml:"contributor"`
			Text struct {
				Text  string `xml:",chardata"`
				Space string `xml:"space,attr"`
			} `xml:"text"`
			Minor   string `xml:"minor"`
			Comment string `xml:"comment"`
		} `xml:"revision"`
	} `xml:"page"`
}

func main() {
	var p Mediawiki
	dat, err := ioutil.ReadFile("/home/deef/workspace/src/docker-dev-makefile/ssr/SSR-27may2020-ABCDEFG-5008.xml")

	if err != nil {
		panic(err)
	}

	if err := xml.Unmarshal(dat, &p); err != nil {
		panic(err)
	}
	//fmt.Println(p)

	n := Mediawiki{
		XMLName:        p.XMLName,
		Text:           p.Text,
		Xmlns:          p.Xmlns,
		Xsi:            p.Xsi,
		SchemaLocation: p.SchemaLocation,
		Version:        p.Version,
		Lang:           p.Lang,
		Siteinfo:       p.Siteinfo,
	}
	for i := 0; i < len(p.Page); i += 10 {
		if i+9 > len(p.Page) {
			n.Page = p.Page[i:]
			fmt.Printf("Min: %d. Max: all\n", i)

		} else {
			n.Page = p.Page[i : i+10]
			fmt.Printf("Min: %d. Max: %d\n", i, i+10)

		}

		n.libTest()
		return
	}
}

func (m *Mediawiki) libTest() {
	w, err := mwclient.New("http://localhost/api.php", "myWikibot")
	if err != nil {
		panic(err)
	}

	//The new password to log in with User@bot is dcgfrm2usi2s9l002qq93lg8ctf3asgf. Please record this for future reference.
	//(For old bots which require the login name to be the same as the eventual username,
	//you can also use User as username and bot@dcgfrm2usi2s9l002qq93lg8ctf3asgf as password.)

	// Log in.
	err = w.Login("User@bot", "dcgfrm2usi2s9l002qq93lg8ctf3asgf")
	if err != nil {
		panic(err)
	}

	out, _ := xml.MarshalIndent(m, " ", "  ")

	// Specify parameters to send.
	parameters := map[string]string{
		//http://localhost/api.php?action=import&interwikiprefix=ssr
		"action":          "import",
		"interwikiprefix": "ssr",
		"xml":             string(out),
	}

	// Make the request.
	resp, err := w.Post(parameters)
	if err != nil {
		panic(err)
	}

	// Print the *jason.Object
	fmt.Println(resp)
}

func (m *Mediawiki) pst(name string) {

	client := &http.Client{}

	token := "f881711b7ba580d947b72b8abda34ef95f13eeea+\\"
	link := "http://localhost/api.php?action=import&interwikiprefix=ssr"

	out, _ := xml.MarshalIndent(m, " ", "  ")

	err := ioutil.WriteFile("hold.xml", out, 0644)
	if err != nil {
		log.Fatal(err)
	}

	//prepare the reader instances to encode
	values := map[string]io.Reader{
		"xml":   mustOpen("hold.xml"), // lets assume its this file
		"token": strings.NewReader(token),
	}
	err = Upload(client, link, values)
	if err != nil {
		panic(err)
	}

}

func (m *Mediawiki) test(client *http.Client, url, token string) {

	var b bytes.Buffer

	w := multipart.NewWriter(&b)

	var fw io.Writer

	fw, err := w.CreateFormField("xml")
	if err != nil {
		panic(err)
	}
	out, _ := xml.MarshalIndent(m, " ", "  ")
	buf := bytes.NewBuffer(out)
	if _, err = io.Copy(fw, buf); err != nil {
		panic(err)
	}

	fw, err = w.CreateFormField("token")
	if err != nil {
		panic(err)
	}
	buf = bytes.NewBuffer([]byte(token))
	if _, err = io.Copy(fw, buf); err != nil {
		panic(err)
	}

	// Don't forget to close the multipart writer.
	// If you don't close it, your request will be missing the terminating boundary.
	w.Close()

	// Now that you have a form, you can submit it to your handler.
	req, err := http.NewRequest("POST", url, &b)
	if err != nil {
		panic(err)

	}
	// Don't forget to set the content type, this will contain the boundary.
	req.Header.Set("Content-Type", "multipart/form-data")

	response, err := client.Do(req)

	if err != nil {
		log.Fatal(err)
	}
	defer response.Body.Close()

	content, err := ioutil.ReadAll(response.Body)

	if err != nil {
		log.Fatal(err)
	}

	err = ioutil.WriteFile("res.html", content, 0644)
	if err != nil {
		log.Fatal(err)
	}

}

func (m *Mediawiki) post(name string) {
	token := "62327d73c9cc0884b38726ed8b25b87c5f13de07+\\"
	link := "http://localhost/api.php?action=import&interwikiprefix=ssr"

	client := &http.Client{}
	m.test(client, link, token)
	return
	//rawCookies := "bitnami_mediawikiUserID=1; " +
	//	"bitnami_mediawikiUserName=User; " +
	//	"bitnami_mediawiki_session=84vealqjqljohkptogo91ost1dun2414"

	//out, _ := xml.MarshalIndent(m, " ", "  ")

	form := url.Values{}
	form.Add("token", token)
	//form.Add("xml", string(out))
	request, err := http.NewRequest("POST", link, strings.NewReader(form.Encode()))

	request.PostForm = form

	response, err := client.Do(request)

	if err != nil {
		log.Fatal(err)
	}
	defer response.Body.Close()

	content, err := ioutil.ReadAll(response.Body)

	if err != nil {
		log.Fatal(err)
	}

	err = ioutil.WriteFile("res.html", content, 0644)
	if err != nil {
		log.Fatal(err)
	}
}

func Upload(client *http.Client, url string, values map[string]io.Reader) (err error) {
	// Prepare a form that you will submit to that URL.
	var b bytes.Buffer
	w := multipart.NewWriter(&b)
	for key, r := range values {
		var fw io.Writer
		if x, ok := r.(io.Closer); ok {
			defer x.Close()
		}
		// Add an image file
		if x, ok := r.(*os.File); ok {
			if fw, err = w.CreateFormFile(key, x.Name()); err != nil {
				return
			}
		} else {
			// Add other fields
			if fw, err = w.CreateFormField(key); err != nil {
				return
			}
		}
		if _, err = io.Copy(fw, r); err != nil {
			return err
		}

	}
	// Don't forget to close the multipart writer.
	// If you don't close it, your request will be missing the terminating boundary.
	w.Close()

	// Now that you have a form, you can submit it to your handler.
	req, err := http.NewRequest("POST", url, &b)
	if err != nil {
		return
	}
	// Don't forget to set the content type, this will contain the boundary.
	req.Header.Set("Content-Type", w.FormDataContentType())

	response, err := client.Do(req)

	if err != nil {
		log.Fatal(err)
	}
	defer response.Body.Close()

	content, err := ioutil.ReadAll(response.Body)

	if err != nil {
		log.Fatal(err)
	}

	err = ioutil.WriteFile("res.html", content, 0644)
	if err != nil {
		log.Fatal(err)
	}
	return
}

func mustOpen(f string) *os.File {
	r, err := os.Open(f)
	if err != nil {
		panic(err)
	}
	return r
}
