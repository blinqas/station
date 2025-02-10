package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
)

func tfc() {
	terraformToken, tokenErr := getTerraformToken()
	organization := "ccbas"

	if tokenErr != nil {
		fmt.Printf("Error retrieving token: %v\n", tokenErr)
		os.Exit(1)
	}

	// Step 1: Get Callback URL from Terraform Cloud
	terraformURL := fmt.Sprintf("https://app.terraform.io/api/v2/organizations/%s/oauth-clients", organization)

	fmt.Print(terraformURL)

	// Prepare the request body
	body := map[string]interface{}{
		"data": map[string]interface{}{
			"type": "oauth-clients",
			"attributes": map[string]string{
				"service-provider": "github",
				"name":             "GitHub Integration",
			},
		},
	}
	bodyBytes, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", terraformURL, bytes.NewBuffer(bodyBytes))
	req.Header.Set("Authorization", "Bearer "+terraformToken)
	req.Header.Set("Content-Type", "application/vnd.api+json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("Error fetching callback URL: %v\n", err)
		os.Exit(1)
	}
	defer resp.Body.Close()

	respBody, _ := ioutil.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusCreated {
		fmt.Printf("Error: %s\n", string(respBody))
		os.Exit(1)
	}

	// Parse the callback URL
	var terraformResponse map[string]interface{}
	json.Unmarshal(respBody, &terraformResponse)
	callbackURL := terraformResponse["data"].(map[string]interface{})["attributes"].(map[string]interface{})["callback-url"].(string)

	fmt.Printf("Callback URL Retrieved: %s\n", callbackURL)

	// Step 2: Create GitHub OAuth App using `gh` CLI
	/*name := "Terraform Cloud Integration"
	homepageURL := "https://app.terraform.io"

	command := fmt.Sprintf(
		`gh api --method POST -H "Accept: application/vnd.github.v3+json" /orgs/YOUR_ORG_NAME/oauth-apps -f name='%s' -f url='%s' -f callback_url='%s'`,
		name, homepageURL, callbackURL,
	)

	cmd := exec.Command("sh", "-c", command)
	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr

	err = cmd.Run()
	if err != nil {
		fmt.Printf("Error creating OAuth App: %s\n", stderr.String())
		os.Exit(1)
	}

	fmt.Printf("OAuth App Created Successfully:\n%s\n", out.String()) */
}

func validate_terroform_cli() {
	// Step 3: Validate Terraform CLI
	cmd := exec.Command("terraform", "version")
	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		fmt.Printf("Failed to run the terraform version command. Ensure that you have installed the Terraform CLI")
		os.Exit(1)
	}
}

func getTerraformToken() (string, error) {
	// Get the home directory
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("unable to get home directory: %v", err)
	}

	// Construct the path to the Terraform credentials file
	credentialsPath := filepath.Join(homeDir, ".terraform.d", "credentials.tfrc.json")

	// Read the credentials file
	credentialsFile, err := os.Open(credentialsPath)
	if err != nil {
		return "", fmt.Errorf("unable to open credentials file: %v", err)
	}
	defer credentialsFile.Close()

	credentialsData, err := io.ReadAll(credentialsFile)
	if err != nil {
		return "", fmt.Errorf("unable to read credentials file: %v", err)
	}

	// Parse the JSON to get the token
	var credentials map[string]interface{}
	err = json.Unmarshal(credentialsData, &credentials)
	if err != nil {
		return "", fmt.Errorf("unable to parse credentials JSON: %v", err)
	}

	token, ok := credentials["credentials"].(map[string]interface{})["app.terraform.io"].(map[string]interface{})["token"].(string)
	if !ok {
		return "", fmt.Errorf("token not found in credentials file")
	}

	return token, nil
}
func getTFCOrganizations(token string) ([]string, error) {
	apiURL := "https://app.terraform.io/api/v2/organizations"

	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return nil, fmt.Errorf("unable to create request: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/vnd.api+json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("error making API request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := ioutil.ReadAll(resp.Body)
		return nil, fmt.Errorf("error response from API: %s", string(body))
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("unable to read response body: %v", err)
	}

	var response map[string]interface{}
	err = json.Unmarshal(body, &response)
	if err != nil {
		return nil, fmt.Errorf("unable to parse response JSON: %v", err)
	}

	organizations := []string{}
	for _, org := range response["data"].([]interface{}) {
		orgName := org.(map[string]interface{})["attributes"].(map[string]interface{})["name"].(string)
		organizations = append(organizations, orgName)
	}

	return organizations, nil
}
