import './MessageForm.css';
import React from "react";
import process from 'process';

export default function MessageForm(props) {
  const [count, setCount] = React.useState(0);
  const [message, setMessage] = React.useState('');

  const classes = []
  classes.push('count')
  if (1024-count < 0){
    classes.push('err')
  }

  const onsubmit = async (event) => {
    event.preventDefault();

    // ❌ prevent sending empty receiver
    if (!props.userReceiverHandle) {
      console.log("No receiver handle provided");
      return;
    }

    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/messages`

      let json = { 
        message: message,
        user_receiver_handle: props.userReceiverHandle
      }

      console.log('onsubmit payload', json)

      const res = await fetch(backend_url, {
        method: "POST",
        headers: {
          'Authorization': `Bearer ${localStorage.getItem("access_token")}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(json)
      });

      let data = await res.json();

      if (res.status === 200) {
        console.log('data:', data)

        if (data.message_group_uuid) {
          window.location.href = `/messages/${data.message_group_uuid}`
        } else {
          props.setMessages(current => [...current, data]);
        }

        // ✅ clear input after send
        setMessage('');
        setCount(0);

      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  }

  const textarea_onchange = (event) => {
    setCount(event.target.value.length);
    setMessage(event.target.value);
  }

  return (
    <form 
      className='message_form'
      onSubmit={onsubmit}
    >
      <textarea
        type="text"
        placeholder="send a direct message..."
        value={message}
        onChange={textarea_onchange} 
      />
      <div className='submit'>
        <div className={classes.join(' ')}>{1024-count}</div>
        <button type='submit'>Message</button>
      </div>
    </form>
  );
}