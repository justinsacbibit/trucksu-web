import React            from 'react';
import { connect }      from 'react-redux';
import BoardsActions    from '../actions/boards';
import Header           from '../layouts/header';
import SessionActions   from '../actions/sessions';

class AuthenticatedContainer extends React.Component {
  componentDidMount() {
    const { dispatch } = this.props;
    //dispatch(BoardsActions.fetchBoards());
  }

  _handleSignOutClick(e) {
    e.preventDefault();

    this.props.dispatch(SessionActions.signOut());
  }

  render() {
    const { currentUser, dispatch, boards, socket, currentBoard } = this.props;

    if (!currentUser) return false;

    return (
      <div id="authentication_container" className="application-container">
        YER LOGGED IN
        <a href="#" onClick={::this._handleSignOutClick}><i className="fa fa-sign-out"/> Sign out</a>
        {/*
        <Header />

        <div className='main-container'>
          {this.props.children}
        </div>
        */}
      </div>
    );
  }
}

const mapStateToProps = (state) => ({
  currentUser: state.session.currentUser,
  //socket: state.session.socket,
  //channel: state.session.channel,
  //boards: state.boards,
  //currentBoard: state.currentBoard,
});

export default connect(mapStateToProps)(AuthenticatedContainer);
