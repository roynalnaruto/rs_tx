[
  :postgrex,
  :ecto,
  :ecto_sql,
  :faker,
  :tzdata,
  :hackney
]
|> Enum.each(&Application.ensure_all_started/1)

require Logger

alias RsTxCore.{Factory, Repo}
alias RsTxCore.Accounts.{User, UserRole, Role}

alias RsTxCore.Projects.{Project, ProjectMetadata}

alias RsTxCore.Attachment

Repo.start_link(pool_size: System.schedulers() + 3)

Logger.info("> Deleting old users")

[
  ProjectMetadata,
  Project,
  UserRole,
  Role,
  User,
  Attachment
]
|> Enum.each(fn schema ->
  Logger.info(">> Deleting #{schema}")
  Repo.delete_all(schema)
end)

Logger.info("> Creating special roles")

password = "Qwer123!"

Logger.info("> Creating sample users with password: `#{password}`")

newuser = Factory.insert(:confirmed_user, email: "newuser@support.com", password: password)
Logger.info(">> Created a KYC tier 1 user: newuser@support.com")

Factory.insert(:project, user_id: newuser.id, user: nil)
Logger.info(">> Created a project for user: newuser@support.com")

Logger.info("> Done with the seeding")
