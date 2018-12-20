require 'docker'
require 'json'
require 'semantic_logger'

module EDURange::Docker
    class InstanceImage
      include SemanticLogger::Loggable

      def self.find(instance)
        label_filter = {
          label: [
            "edu.range.instance=#{instance.name}",
            "edu.range.scenario=#{instance.scenario.name}",
          ]
        }
        Docker::Image.all(all: false, filters: [label_filter.to_json]).first
      end

      def self.dockerfile_contents(instance)
        Dockerfile.new(instance).render
      end

      def self.build instance
        logger.trace 'building image', instance: instance.name
        tmp_dir_prefix = "edurange_docker_image_for_#{instance.name}_"
        Dir.mktmpdir tmp_dir_prefix do |dir|
          tmp_path = Pathname.new(dir)
          InstanceImage.create_build_directory(tmp_path, instance)

          # build image from tmp directory
          Docker::Image.build_from_dir(dir, t: instance.name.downcase) # t is the image 'tag'
        end
      end

      # Add files to a directory to be used as a docker context to build an image for this instance.
      def self.create_build_directory(path, instance)
        path.mkdir if not path.exist?
        # add script files to directory
        instance.scripts.each do |script|
          logger.trace(event: 'installing_script', script: script.name)
          script_path = path + script.name
          script_path.open('w') do |script_file|
            contents = script.contents_for instance
            # kind of ugly to have this here.
            if contents.include? "\r" then
              raise "script '#{script.name}' contains windows carriage returns"
            end
            script_file.write(contents)
          end
        end

        # add dockerfile to directory
        dockerfile_path = path + 'Dockerfile'
        dockerfile_path.open('w') do |dockerfile|
          dockerfile.write(dockerfile_contents instance)
        end
      end

    end
end
