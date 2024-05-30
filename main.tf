terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.31.1"
    }
  }
}

provider "google" {
  # Configuration options
  region = "us-central1"
  zone = "us-central1-a"
  project = "leviathan-424601"
  credentials = "leviathan-424601-9440b04681df.json"
}

// Step 1: This code block creates the bucket
resource "google_storage_bucket" "bucket" {
  name          = "bucket-created-with-terraform"
  location      = "us-central1"
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  uniform_bucket_level_access = false
}

/***********************************************************************/
/****************** JRemo's code from gcpstorage repo ******************/
/***********************************************************************/

// Step 2: This code block makes the bucket public
resource "google_storage_bucket_acl" "bucket_acl" {
  bucket         = google_storage_bucket.bucket.name
  predefined_acl = "publicRead"
}

// Step 3: This code block uploads the html file into the bucket we created in Step 1 
resource "google_storage_bucket_object" "upload_html" {
  for_each     = fileset("${path.module}/", "*.html")
  bucket       = google_storage_bucket.bucket.name
  name         = each.value
  source       = "${path.module}/${each.value}"
  content_type = "text/html"
}

// Step 4: And this code block makes the index.html file public 
// Public ACL for each HTML file
resource "google_storage_object_acl" "html_acl" {
  for_each       = google_storage_bucket_object.upload_html
  bucket         = google_storage_bucket_object.upload_html[each.key].bucket
  object         = google_storage_bucket_object.upload_html[each.key].name
  predefined_acl = "publicRead"
}

// Step 5: Now we just rinse and repeat for the images (1. upload them 2. make them public)
resource "google_storage_bucket_object" "upload_images" {
  for_each     = fileset("${path.module}/", "*.jpg")
  bucket       = google_storage_bucket.bucket.name
  name         = each.value
  source       = "${path.module}/${each.value}"
  content_type = "image/jpeg"
}

// Step 6: This code block makes the images public
resource "google_storage_object_acl" "image_acl" {
  for_each       = google_storage_bucket_object.upload_images
  bucket         = google_storage_bucket_object.upload_images[each.key].bucket
  object         = google_storage_bucket_object.upload_images[each.key].name
  predefined_acl = "publicRead"
}

// This code block outputs whatever is stored in value to your terminal (in this case it's a url)
// This is helpful because then you don't have to go to Google Cloud Console to get the url
output "website_url" {
  value = "https://storage.googleapis.com/${google_storage_bucket.bucket.name}/index.html"
}
