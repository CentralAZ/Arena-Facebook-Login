<%@ WebService Language="C#" Class="AuthenticationService" %>

using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Script.Services;
using System.Web.Security;
using System.Web.Services;
using Arena.Core;
using Arena.Custom.Cccev.FrameworkUtils.Entity;
using Arena.Custom.Cccev.FrameworkUtils.FrameworkConstants;
using Arena.DataLayer.Core;
using Arena.Portal;
using Arena.Security;
using Facebook;

[WebService(Namespace = "http://localhost/Arena")]
[WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
[ScriptService]
public class AuthenticationService : WebService 
{
    
    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public int Authenticate(string username, string password)
    {
        // Check HTTP_X_FORWARDED_FOR header to capture requests behind proxies
        var ipAddress = HttpContext.Current.Request.ServerVariables["HTTP_X_FORWARDED_FOR"];
        
        if (string.IsNullOrEmpty(ipAddress))
        {
            ipAddress = HttpContext.Current.Request.UserHostAddress;
        }
        
        var personID = PortalLogin.Authenticate(username, password, ipAddress, ArenaContext.Current.Organization.OrganizationID);

        if (personID != -1)
        {
            var login = new Login(username);
            FormsAuthentication.SetAuthCookie(login.LoginID, false);
            HttpContext.Current.Response.Cookies["portalroles"].Value = string.Empty;
            return personID;
        }

        return -1;
    }
    
    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public bool ConnectAccountToFacebook(string accessToken, string state)
    {
        var st = HttpContext.Current.Session["CentralAZ.Web.FacebookAuth.State"].ToString();
        var person = ArenaContext.Current.Person;

        if (st != state || (person == null || person.PersonID == -1))
        {
            return false;
        }

        try
        {
            var client = new FacebookClient(accessToken);
            var result = (IDictionary<string, object>)client.Get("me") ?? new Dictionary<string, object> { { "id", string.Empty } };
            var id = result["id"].ToString();
            var attribute = new Arena.Core.Attribute(SystemGuids.FACEBOOK_USER_ID_ATTRIBUTE);
            var personAttribute = new PersonAttribute(person.PersonID, attribute.AttributeId);
            personAttribute.StringValue = id;
            personAttribute.Save(ArenaContext.Current.Organization.OrganizationID, ArenaContext.Current.User.Identity.Name);
            return true;
        }
        catch (FacebookApiException ex)
        {
            new ExceptionHistoryData().AddUpdate_Exception(ex, ArenaContext.Current.Organization.OrganizationID,
                "Cccev.Web", ArenaContext.Current.ServerUrl);
            return false;
        }
    }
    
    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public bool OptOutOfFacebookConnection(string state)
    {
        try
        {
            var person = ArenaContext.Current.Person;
            var attribute = new Arena.Core.Attribute(SystemGuids.FACEBOOK_OPT_OUT_ATTRIBUTE);
            var personAttribute = new PersonAttribute(person.PersonID, attribute.AttributeId);
            personAttribute.IntValue = 1;
            personAttribute.Save(ArenaContext.Current.Organization.OrganizationID, ArenaContext.Current.User.Identity.Name);
            return true;
        }
        catch (Exception)
        {
            return false;
        }
    }

    [WebMethod(EnableSession = true)]
    [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
    public int AuthenticateFacebook(string accessToken, string state)
    {
        var st = HttpContext.Current.Session["CentralAZ.Web.FacebookAuth.State"].ToString();
        const string CREATED_BY = "FacebookLogin";

        if (st != state)
        {
            return -1;
        }
        
        try
        {
            var client = new FacebookClient(accessToken);
            var result = (IDictionary<string, object>) client.Get("me") ?? new Dictionary<string, object> { { "id", string.Empty } };

            var id = result["id"].ToString();
            var people = new PersonCollection();
            people.LoadByFacebookIdAndAttributeGuid(id, SystemGuids.FACEBOOK_USER_ID_ATTRIBUTE);
            var person = people.FirstOrDefault();
            string password;
            string loginID;

            // If we find a person in Arena with the correct Facebook ID, attempt to log them in.
            if (person != null)
            {
                var login = new LoginCollection(person.PersonID).FirstOrDefault();

                // If there's not an existing login in our system, create one for them.
                loginID = login != null ? login.LoginID : person.AddLogin(true, CREATED_BY, out password);
                FormsAuthentication.SetAuthCookie(loginID, false);
                HttpContext.Current.Response.Cookies["portalroles"].Value = string.Empty;
                return person.PersonID;
            }

            return -1;
        }
        catch (FacebookApiException ex)
        {
            new ExceptionHistoryData().AddUpdate_Exception(ex, ArenaContext.Current.Organization.OrganizationID,
                "Cccev.Web", ArenaContext.Current.ServerUrl);
            return -1;
        }
    }
}