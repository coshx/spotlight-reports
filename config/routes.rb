Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'teachers#index'

  # App Setup
  post 'lti_tool' => 'lti#launch_tool'
  get '/tool_config.xml' => 'lti#config_xml'

  # Getting data
  get '/school/:id' => 'teachers#get_teachers'
  get '/teacher_details/:id' => 'teachers#get_teacher_details'
  get '/course_graph_data/:id' => 'teachers#get_course_graph_data'
  get '/course_grid_data/:id' => 'teachers#get_course_grid_data'
  get '/course_student_data/:id' => 'teachers#get_student_grid_data'
  get '/course_grade_data/:id' => 'teachers#get_course_grade_data'
  post '/school_averages/' => 'courses#get_school_averages'


  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
