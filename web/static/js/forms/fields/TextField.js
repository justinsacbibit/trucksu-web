import React from 'react';

const TextField = React.createClass({
	render() {
		return (
			<input
        id={`text_${this.props.name}`}
        {...this.props}
      />
		);
	}
});

export default TextField;