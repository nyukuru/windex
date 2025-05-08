/*
Copyright (C) 2020 M-Labs Limited.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package main

import (
	"archive/tar"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
)

func Untar(dst string, r io.Reader) error {

	tr := tar.NewReader(r)

	for {
		header, err := tr.Next()

		switch {

		case err == io.EOF:
			return nil
		case err != nil:
			return err

		case header == nil:
			continue
		}

		target := filepath.Join(dst, header.Name)

		switch header.Typeflag {

		case tar.TypeDir:
			if _, err := os.Stat(target); err != nil {
				if err := os.MkdirAll(target, 0755); err != nil {
					return err
				}
			}

		case tar.TypeReg:
			f, err := os.OpenFile(target, os.O_CREATE|os.O_RDWR, os.FileMode(header.Mode))
			if err != nil {
				return err
			}

			if _, err := io.Copy(f, tr); err != nil {
				return err
			}

			f.Close()
		}
	}
}

func InstallBundle(bundlePath string) error {

	reader, err := os.Open(bundlePath)
	if err != nil {
		log.Fatal(err)
	}

	workDir, err := ioutil.TempDir("", "bundle_install")
	if err != nil {
		return err
	}
	defer os.RemoveAll(workDir)

	err = Untar(workDir, reader)
	if err != nil {
		return err
	}

	installScript := filepath.Join(workDir, "install.ps1")

	cmd := exec.Command("powershell", installScript)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Dir = workDir
	err = cmd.Run()

	return err
}

func main() {
	// Get path relative to binary
	baseDir, err := filepath.Abs(filepath.Dir(os.Args[0]))
	if err != nil {
		log.Fatal(err)
	}

	var dirs = [2]string{"bootstrap", "user"}

	for _, pkgDir := range dirs {

		dir := filepath.Join(baseDir, pkgDir)

		files, err := ioutil.ReadDir(dir)
		if err != nil {
			log.Fatal(err)
		}

		for _, file := range files {
			bundle := filepath.Join(dir, file.Name())
			fmt.Println(fmt.Sprintf("Installing: %s", bundle))
			err := InstallBundle(bundle)
			if err != nil {
				log.Fatal(err)
			}
		}

	}

}
