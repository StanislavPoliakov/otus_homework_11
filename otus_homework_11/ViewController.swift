//
//  ViewController.swift
//  otus_homework_11
//
//  Created by Поляков Станислав Денисович on 12.05.2024.
//

import UIKit

class ViewController: UIViewController {
    
    private lazy var label1: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "label1"
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.backgroundColor = .systemMint
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var label2: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "label2"
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.backgroundColor = .magenta
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.image = UIImage(systemName: "scribble.variable")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .yellow
        return imageView
    }()
    
    private var portraitConstraints: [NSLayoutConstraint] = []
    private var landscapeConstraints: [NSLayoutConstraint] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        view.addSubview(label1)
        view.addSubview(label2)
        view.addSubview(imageView)
        
        /*
         Это начинает выглядеть, как челлендж )
         - старт приложения с холодного эмулятора (не загруженного) в landscape-режиме
         - старт приложения с прогретого эмулятора в landscape-режиме
         
         Короче, запускать надо в портретном режиме
         */
        applyPortraitConstraints()
    }
    
    private func applyPortraitConstraints() {
        if portraitConstraints.isEmpty {
            let horizontalMargin = (view.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right - label1.intrinsicContentSize.width - label2.intrinsicContentSize.width) / 3
            
            /*
             Минимальное из:
             - Расстояние между view.safeArea.centerY и imageView.centerY = 1/10 от высоты safeArea
             - Расстояние между view.label2/label1.top и imageView.bottom = 10, то есть приводим к сопоставимым величинам - расстояние между view.safeArea.centerY и imageView.centerY = label2/label1.height / 2 + 10 + imageView.height / 2
             */
            let verticalMargin = min(view.bounds.height / 10, abs(label2.intrinsicContentSize.height / 2 + 10 + imageView.intrinsicContentSize.height / 2))
            
            portraitConstraints = [
                label1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalMargin),
                label2.leadingAnchor.constraint(equalTo: label1.trailingAnchor, constant: horizontalMargin),
                label2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalMargin),
                label1.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
                label2.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
                
                imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -verticalMargin),
                imageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            ]
        }
        
        NSLayoutConstraint.activate(portraitConstraints)
    }
    
    private func applyLandscapeConstraints() {
        if landscapeConstraints.isEmpty {
            let widths = label1.intrinsicContentSize.width + label2.intrinsicContentSize.width + imageView.intrinsicContentSize.width
            let safeAreaWidth = (view.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right)
            let horizontalMargin = (safeAreaWidth - 40 - widths) / 2
            
            landscapeConstraints = [
                label1.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                imageView.leadingAnchor.constraint(equalTo: label1.trailingAnchor, constant: horizontalMargin),
                label2.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: horizontalMargin),
                label2.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                label1.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
                imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: imageView.intrinsicContentSize.width),
                label2.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            ]
        }

        NSLayoutConstraint.activate(landscapeConstraints)
    }
    
    /*
     Почему viewWillTransition:
     Дело в том, что деактивация старых констрейнтов и активация новых в viewDidLayoutSubviews приводит к списку warnings: и правда, мы перевернули устройство, система отрисовала иерархию со "старыми" констрейнтами - насыпала в лог об этом, а потом их отменила.
     Поэтому, отменить старые констрейнты лучше здесь - ведь следующий шаг - переворот и отрисовка иерархии. Пусть рисует без констрейтов, а потом мы применим актуальные (из viewDidLoadSubviews).
     */
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if UIDevice.current.orientation.isPortrait {
            NSLayoutConstraint.deactivate(landscapeConstraints)
        } else if UIDevice.current.orientation.isLandscape {
            NSLayoutConstraint.deactivate(portraitConstraints)
        }
    }

    /*
     Любопытный момент: if isPortrait { } else { } - попадает сразу в else. Система на самом старте не идентифицирует девайс в портретном режиме, зато идентифицирует его несколько позже ))
     
     Собственно, почему здесь, а не в viewWillTransition:
     viewWillTransition - будет говорить о намерении пользователят перевернуть устройство, при этом фактические bounds.width/height соответствуют текущему состоянию (пока еще не перевернутому). И опираться на то, что БУДЕТ, но НЕ ПРОИЗОШЛО - не совсем верно. Придется брать height, вместо width - они же поменяются местами. Более того - нарастет safeArea в landscape-режиме...
     Короче говоря - такое...
     Поэтому фактическое применение ограничений (констрейнтов) лучше сделать по факту переворота - после отрисовкой системой всей иерархии.
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if UIDevice.current.orientation.isPortrait {
            applyPortraitConstraints()
        } else if UIDevice.current.orientation.isLandscape {
            applyLandscapeConstraints()
        }
    }
}

