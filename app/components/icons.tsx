/** @jsxImportSource theme-ui */
export function DotsIcon({ className = "" }) {
  return (
    <svg
      sx={{
        stroke: "text",
      }}
      className={className}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      fill="none"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="1.5"
      viewBox="0 0 24 24"
    >
      <path stroke="none" d="M0 0h24v24H0z"></path>
      <circle cx="12" cy="12" r="9"></circle>
      <path d="M8 12L8 12.01"></path>
      <path d="M12 12L12 12.01"></path>
      <path d="M16 12L16 12.01"></path>
    </svg>
  )
}
