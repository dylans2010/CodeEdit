import { Links, Meta, Outlet, Scripts } from "@remix-run/react";

export default function Root() {
  return (
    <html lang="en">
      <head><Meta /><Links /></head>
      <body style={{ fontFamily: "system-ui", padding: "2rem" }}>
        <h1>Welcome to {{PROJECT_NAME}}</h1>
        <Outlet />
        <Scripts />
      </body>
    </html>
  );
}
