import './ProfileForm.css';
import React from "react";
import process from 'process';
import {getAccessToken} from 'lib/CheckAuth';

export default function ProfileForm(props) {
  const [bio, setBio] = React.useState('');
  const [displayName, setDisplayName] = React.useState('');

  React.useEffect(()=>{
    setBio(props.profile.bio || '');
    setDisplayName(props.profile.display_name);
  }, [props.profile])

  const s3uploadkey = async (extension) => {
    const apiUrl = process.env.REACT_APP_API_GATEWAY_ENDPOINT_URL;
    
    if (!apiUrl) {
      //console.error('REACT_APP_API_GATEWAY_ENDPOINT_URL is not set!');
      throw new Error('API Gateway URL is not configured');
    }

    const gateway_url = `${apiUrl}/avatars/key_upload`;
    console.log('Calling:', gateway_url);

    await getAccessToken();
    const access_token = localStorage.getItem("access_token");

    const res = await fetch(gateway_url, {
      method: "POST",
      body: JSON.stringify({ extension }),
      headers: {
        'Authorization': `Bearer ${access_token}`,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    });

    if (!res.ok) {
      const text = await res.text();
      //console.error('API error:', res.status, text);
      throw new Error(`API returned ${res.status}`);
    }

    const data = await res.json();
    return data.url;
  };

  const s3upload = async (event) => {
    const file = event.target.files[0];
    if (!file) return;

    const extension = file.name.split('.').pop();
    
    let presignedurl;
    try {
      presignedurl = await s3uploadkey(extension);
    } catch (err) {
      //console.error('Failed to get presigned URL:', err);
      alert('Upload failed: Could not get upload URL. Check console.');
      return;
    }

    if (!presignedurl) {
      //console.error('No presigned URL returned');
      return;
    }

    try {
      const res = await fetch(presignedurl, {
        method: "PUT",
        body: file,
        headers: {
          'Content-Type': file.type
        }
      });
      
      if (res.status === 200) {
        //console.log('Upload successful');
      } else {
        //console.error('S3 upload failed:', res.status);
      }
    } catch (err) {
      //console.error('S3 upload error:', err);
    }
  };

  const onsubmit = async (event) => {
    event.preventDefault();
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/profile/update`
      await getAccessToken()
      const access_token = localStorage.getItem("access_token")
      const res = await fetch(backend_url, {
        method: "POST",
        headers: {
          'Authorization': `Bearer ${access_token}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          bio: bio,
          display_name: displayName
        }),
      });
      let data = await res.json();
      if (res.status === 200) {
        //console.log('Profile updated successfully');
        setBio(null)
        setDisplayName(null)
        props.setPopped(false)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err); 
    }
  }

  const bio_onchange = (event) => {
    setBio(event.target.value);
  }

  const display_name_onchange = (event) => {
    setDisplayName(event.target.value);
  }

  const close = (event)=> {
    if (event.target.classList.contains("profile_popup")) {
      props.setPopped(false)
    }
  }

  if (props.popped === true) {
    return (
      <div className="popup_form_wrap profile_popup" onClick={close}>
        <form 
          className='profile_form popup_form'
          onSubmit={onsubmit}
        >
          <div className="popup_heading">
            <div className="popup_title">Edit Profile</div>
            <div className='submit'>
              <button type='submit'>Save</button>
            </div>
          </div>
          <div className="popup_content">
            
          <input type="file" name="avatarupload" onChange={s3upload} />

            <div className="field display_name">
              <label>Display Name</label>
              <input
                type="text"
                placeholder="Display Name"
                value={displayName}
                onChange={display_name_onchange} 
              />
            </div>
            <div className="field bio">
              <label>Bio</label>
              <textarea
                placeholder="Bio"
                value={bio}
                onChange={bio_onchange} 
              />
            </div>
          </div>
        </form>
      </div>
    );
  }
}