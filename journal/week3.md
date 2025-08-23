# Week 3 — Decentralized Authentication
---

# Provision via ClickOps a Amazon Cognito User Pool
---
### Using the search bar, search for AWS COGNITO
###Click on Create User Pool
[!Create User Pool]()

Then click on preferred sign-in options, click on next when done
[!Create User Pool]()


Choose password police, ensure to include 1 number, special character, 1 uppercase and lowercase to streghten the password
NOTE: It's recommended to always set up MFA to secure access, but we won't be going through that process now 

Set an mode of account recovery incase of forgotten password. Email delivery is free and that will be what we will be using. SMS incurs bills. Then click on Next
[!Create User Pool]()

Enable the cognito to send and confirm and then chose mode to verify, email verification is being used
Choose required attributes matching with your Frontend UI and information you need from users. Click on Next
[!Create User Pool]()


"Send Email with AMAZON SES" is recommended for higher workloads with a registered email with AMAZON SES, incurs charges, Send Email with cognito will be used here. Click on Next
[!Create User Pool]()


Put in preferred pool name and then make the APP TYPE confidential as to nmake it private and generate a secret for use. Enter friendly name for App ensure it's generating a client secret then click on Next
[!Create User Pool]()

Review details filled, click create to create the preferred userpool.

---
# Install and configure Amplify client-side library for Amazon Congito

Prior before now, the client-side has relied on on cookies. open the directory frontend-react-js/src/App.js with your preferred text editor. Include the below code
[!Create User Pool]()

Update docker-compose.yaml to integrate with AWS Cognito and in your .env file update with the credentiials as well such as your client ID, App Secret
[!Create User Pool]()

Return to AWS Console, open your User pool, click on APP Integration, scroll down to get your CLIENT ID, Copy the User pool ID from the userpool overview. 
Your cognito region should be the region you created the User pool in the same with project region.

# Implement API calls to Amazon Coginto for custom login, signup, recovery and forgot password page

The respective directories are frontend-react-js/src/pages/signinpage.js, frontend-react-js/src/pages/signuppage.js, frontend-react-js/src/pages/recoverpage.js frontend-react-js/src/pages/confirmationpage.js

# Signin page
open the directory frontend-react-js/src/pages/signinpage.js with your editor

```js
  import { Auth } from 'aws-amplify;
```
 Add the above code to import the 'Auth' object from the 'aws-amplify' library
 ```js
  const [email, setEmail] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [errors, setErrors] = React.useState('');
```
 Update the react state with the above code then paste the below code too
```js
  const onsubmit = async (event) => {
    setErrors('')
    event.preventDefault();
    Auth.signIn(email, password)
    .then(user => {
      console.log('user',user)
      localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken)
      window.location.href = "/"
    })
    .catch(error => { 
      if (error.code == 'UserNotConfirmedException') {
        window.location.href = "/confirm"
      }
      setErrors(error.message)
    });
    return false
  }

  const email_onchange = (event) => {
    setEmail(event.target.value);
  }
  const password_onchange = (event) => {
    setPassword(event.target.value);
  }

  let el_errors;
  if (errors){
    el_errors = <div className='errors'>{errors}</div>;
  }
```
# Signup
open the directory frontend-react-js/src/pages/signuppage.js with your editor
For the signup import the Auth object the aws-amplify librabry

```js
  import { Auth } from 'aws-amplify;
```

update the react state

```js
 const [name, setName] = React.useState('');
 const [email, setEmail] = React.useState('');
 const [username, setUsername] = React.useState('');
 const [password, setPassword] = React.useState(''); 
 const [errors, setErrors] = React.useState('');
```

update with this lines of codes as well

```js
 const onsubmit = async (event) => {
    event.preventDefault();
    setErrors('')
    try {
        const { user } = await Auth.signUp({
          username: email,
          password: password,
          attributes: {
              name: name,
              email: email,
              preferred_username: username,
          },
          autoSignIn: { // optional - enables auto sign in after user is confirmed
              enabled: true,
          }
        });
        console.log(user);
        window.location.href = `/confirm?email=${email}`
    } catch (error) {
        console.log(error);
        setErrors(error.message)
    }
    return false
  }
  
  
  const name_onchange = (event) => {
    setName(event.target.value);
  }
  const email_onchange = (event) => {
    setEmail(event.target.value);
  }
  const username_onchange = (event) => {
    setUsername(event.target.value);
  }
  const password_onchange = (event) => {
    setPassword(event.target.value);
  }

  let el_errors;
  if (errors){
    el_errors = <div className='errors'>{errors}</div>;
  }
```

# Confirmation page
After susccesfull signup, the confirmationpage needs to update Authenticate with the received delivered code to authenticate user signup

```js
const resend_code = async (event) => {
  setCognitoErrors('')
  try {
    await Auth.resendSignUp(email);
    console.log('code resent successfully');
    setCodeSent(true)
  } catch (err) {
    // does not return a code
    // does cognito always return english
    // for this to be an okay match?
    console.log(err)
    if (err.message == 'Username cannot be empty'){
      setCognitoErrors("You need to provide an email in order to send Resend Activiation Code")   
    } else if (err.message == "Username/client id combination not found."){
      setCognitoErrors("Email is invalid or cannot be found.")   
    }
  }
}

const onsubmit = async (event) => {
  event.preventDefault();
  setCognitoErrors('')
  try {
    await Auth.confirmSignUp(email, code);
    window.location.href = "/"
  } catch (error) {
    setCognitoErrors(error.message)
  }
  return false
}
```
To recover the forgotten passwords, update the code to reset passwords from the pool
# Recover page

import AUTH as done from the previous steps above

update the react state with the below codes 
``` js
  const [username, setUsername] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [passwordAgain, setPasswordAgain] = React.useState('');
  const [code, setCode] = React.useState('');
  const [errors, setErrors] = React.useState('');
  const [formState, setFormState] = React.useState('send_code');
```
Update with this block of code as well

```js
 const onsubmit_send_code = async (event) => {
    event.preventDefault();
    setErrors('')
    Auth.forgotPassword(username)
    .then((data) => setFormState('confirm_code') )
    .catch((err) => setErrors(err.message) );
    return false
  }
  const onsubmit_confirm_code = async (event) => {
    event.preventDefault();
    setErrors('')
    if (password == passwordAgain){
      Auth.forgotPasswordSubmit(username, code, password)
      .then((data) => setFormState('success'))
      .catch((err) => setErrors(err.message) );
    } else {
      setCognitoErrors('Passwords do not match')
    }
    return false
  }

  const username_onchange = (event) => {
    setUsername(event.target.value);
  }
  const password_onchange = (event) => {
    setPassword(event.target.value);
  }
  const password_again_onchange = (event) => {
    setPasswordAgain(event.target.value);
  }
  const code_onchange = (event) => {
    setCode(event.target.value);
  }

  let el_errors;
  if (errors){
    el_errors = <div className='errors'>{errors}</div>;
  }
```
---

# Show conditional elements and data based on logged in or logged out
To show conditional elements when logged in or logged out, update the frontend-react-js/src/components/Desktopnavigation.js and frontend-react-js/src/components/desktopsidebar.js

# Desktopnavigation.js

update frontend-react-js/src/components/Desktopnavigation.js to show conditionally information to users when logged in or logged out

```js
import './DesktopNavigation.css';
import {ReactComponent as Logo} from './svg/logo.svg';
import DesktopNavigationLink from '../components/DesktopNavigationLink';
import CrudButton from '../components/CrudButton';
import ProfileInfo from '../components/ProfileInfo';

export default function DesktopNavigation(props) {

  let button;
  let profile;
  let notificationsLink;
  let messagesLink;
  let profileLink;
  if (props.user) {
    button = <CrudButton setPopped={props.setPopped} />;
    profile = <ProfileInfo user={props.user} />;
    notificationsLink = <DesktopNavigationLink 
      url="/notifications" 
      name="Notifications" 
      handle="notifications" 
      active={props.active} />;
    messagesLink = <DesktopNavigationLink 
      url="/messages"
      name="Messages"
      handle="messages" 
      active={props.active} />
    profileLink = <DesktopNavigationLink 
      url="/@andrewbrown" 
      name="Profile"
      handle="profile"
      active={props.active} />
  }

  return (
    <nav>
      <Logo className='logo' />
      <DesktopNavigationLink url="/" 
        name="Home"
        handle="home"
        active={props.active} />
      {notificationsLink}
      {messagesLink}
      {profileLink}
      <DesktopNavigationLink url="/#" 
        name="More" 
        handle="more"
        active={props.active} />
      {button}
      {profile}
    </nav>
  );
}
```

## Desktopsidebar

```js
import './DesktopSidebar.css';
import Search from '../components/Search';
import TrendingSection from '../components/TrendingsSection'
import SuggestedUsersSection from '../components/SuggestedUsersSection'
import JoinSection from '../components/JoinSection'

export default function DesktopSidebar(props) {
  const trendings = [
    {"hashtag": "100DaysOfCloud", "count": 2053 },
    {"hashtag": "CloudProject", "count": 8253 },
    {"hashtag": "AWS", "count": 9053 },
    {"hashtag": "FreeWillyReboot", "count": 7753 }
  ]

  const users = [
    {"display_name": "Andrew Brown", "handle": "andrewbrown"}
  ]

  let trending;
  if (props.user) {
    trending = <TrendingSection trendings={trendings} />
  }

  let suggested;
  if (props.user) {
    suggested = <SuggestedUsersSection users={users} />
  }
  let join;
  if (props.user) {
  } else {
    join = <JoinSection />
  }

  return (
    <section>
      <Search />
      {trending}
      {suggested}
      {join}
      <footer>
        <a href="#">About</a>
        <a href="#">Terms of Service</a>
        <a href="#">Privacy Policy</a>
      </footer>
    </section>
  );
}
```

finally update profileinfo.js in the components directory

```js
import { Auth } from 'aws-amplify';

const signOut = async () => {
  try {
      await Auth.signOut({ global: true });
      window.location.href = "/"
  } catch (error) {
      console.log('error signing out: ', error);
  }
}
```









ERROR ENCOUNTERED 
Currently facing this issue, and it's not making me progress with the COGNITO setup, 
Client 3li45s2a3no4tepin1lpfvpr8j is configured with secret but SECRET_HASH was not received  followed up with this github issues `https://github.com/aws-amplify/amplify-js/issues/13568`