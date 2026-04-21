<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="hp://www.w3.org/1999/XSL/Transorm">
    <xsl:template match="/">
        <html>
            <head>
                <tle>XML-14K15A0501</tle>
            </head>
            <body>
                <style> table { border-collapse: collapse; width: 100%; } th { ont-size: 18px; color: blue; border: 1px solid black; padding: 8px; text-align: le; } tr:nth-child(even) { background-color: #222; } th:hover{ background-color: black; color:white; } tr:hover { background-color: black; color:white; } td { border: 1px solid black; padding: 8px; vercal-align: top; } td.salary { text-align: right; } </style>
                <table>
                    <tr>
                        <th>Username</th>
                        <th>Password</th>
                        <th>First Name</th>
                        <th>Last Name</th>
                        <th>Gender</th>
                        <th>Email</th>
                        <th>Posion</th>
                        <th>Salary</th>
                        <th>Contact</th>
                    </tr>
                    <xsl:or-each select="company/employee">
                        <tr>
                            <td>
                                <xsl:value-o select="username"/>
                            </td>
                            <td>
                                <xsl:value-o select="password"/>
                            </td>
                            <td>
                                <xsl:value-o select="frstname"/>
                            </td>
                            <td>
                                <xsl:value-o select="lastname"/>
                            </td>
                            <td>
                                <xsl:value-o select="gender"/>
                            </td>
                            <td>
                                <xsl:value-o select="email"/>
                            </td>
                            <td>
                                <xsl:value-o select="posion"/>
                            </td>
                            <td class="salary"> ₹<xsl:value-o select="salary"/>
                            </td>
                            <td>
                                <xsl:value-o select="contact"/>
                            </td>
                        </tr>
                    </xsl:or-each>
                </table>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>