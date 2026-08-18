# Privacy Policy — Blossom Beauty Studio (Beauty Parlour Management)

**Last updated:** [18/08/2026]

This Privacy Policy explains what data the Blossom Beauty Studio salon management app ("the App") collects, how it is stored, and how Google Sign-In / Google Drive is used for backup and restore.

## 1. Who this applies to

The App is used by beauty salon owners to manage their own customers, appointments, services, billing, inventory, and expenses. This policy applies to the salon owner using the App ("you").

## 2. What data the App collects and stores

All business data you enter into the App is stored **locally on your device** in a private, encrypted-at-rest app database. This includes:

- Customer names, phone numbers, email addresses, and birthdays
- Appointment and visit history
- Billing and invoice records
- Services, membership, and package details
- Inventory and expense records
- WhatsApp message templates you create or edit
- Your salon's business profile (owner name, phone number, Gmail address, business name), entered during first-time setup

The App does not send this data to any server operated by us. There is no backend — the App works fully offline except for the optional Google Drive backup feature described below.

## 3. Google Sign-In and Google Drive backup

If you choose to use the "Back Up to Google Drive" feature, the App will:

- Ask you to sign in with your Google account
- Request access to a single Google API scope: **Drive App Data** (`drive.appdata`)
- Upload one file containing an export of your App data (the same data listed in Section 2) to a hidden, app-private folder in your Google Drive

**What this scope does and does not allow:**
- The App can only read and write files it created itself, inside a storage area that is invisible in your regular Google Drive and cannot be accessed by any other app or by us.
- The App cannot see, read, modify, or delete any other files in your Google Drive.
- We (the developer) do not have access to your Google Drive or the backup file stored there. Only you, signed into your own Google account, can retrieve it.

Restoring a backup (e.g. after switching phones) downloads this same file from your Google Drive back onto your new device and replaces the App's local data with it.

You can revoke the App's access to your Google account at any time via your [Google Account permissions page](https://myaccount.google.com/permissions). Revoking access does not delete the backup file already stored in your Drive; you can delete it yourself from Drive's "Manage Apps" storage settings, or it will simply become inaccessible to the App.

## 4. Data sharing

We do not sell, rent, or share your data (customer records, business data, or Google account information) with any third party, advertiser, or analytics service. The App contains no advertising and no third-party trackers.

## 5. Data retention and deletion

- Local data remains on your device until you uninstall the App or clear its data.
- Google Drive backup data remains in your Drive until you delete it (via the App, via Drive's app storage settings, or by revoking the App's Google account access) or delete your Google account.

## 6. Children's privacy

The App is a business tool intended for use by adult salon owners and staff. It is not directed at children, and we do not knowingly collect data from children.

## 7. Changes to this policy

If this policy changes, the "Last updated" date above will be revised. Continued use of the App after changes take effect constitutes acceptance of the revised policy.

## 8. Contact

For questions about this policy or your data, contact: **[shivamraykhere2000@gmail.com]**

---

*This document should be hosted at a public URL (e.g. GitHub Pages, a simple static site, or your business website) and that URL entered as the Privacy Policy URL in Google Cloud Console → OAuth consent screen.*
